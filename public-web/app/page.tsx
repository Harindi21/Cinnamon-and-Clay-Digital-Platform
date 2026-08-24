import Image from 'next/image';
import { Gallery } from '@/components/gallery';
import { connection } from 'next/server';
import { getPublicReviews } from '@/lib/reviews';

import { formatMoney, getMenu } from '@/lib/catalog';
import {
  getContact,
  getSiteContent,
  whatsappHref
} from '@/lib/site';
import {
  getPublicMedia,
  mediaSrc,
  objectPosition
} from '@/lib/media';

export default async function Home() {
  await connection();

const [
  menu,
  content,
  contact,
  media,
  reviewData
] = await Promise.all([
  getMenu(),
  getSiteContent(),
  getContact(),
  getPublicMedia(),
  getPublicReviews()
]);

  const whatsAppUrl = whatsappHref(contact.whatsapp);

  return (
    <main>
      {/* Hero */}
      <section className="hero">
        {media.hero && (
          <Image
            className="heroMedia"
            src={mediaSrc(media.hero)}
            alt={media.hero.alt}
            fill
            priority
            sizes="100vw"
            style={{ objectPosition: objectPosition(media.hero) }}
          />
        )}

        <div className="shell heroContent">
          <p className="kicker">
            {content.brand.heroNote}
          </p>

          <h1>{content.brand.name}</h1>

          <p className="tagline">
            {content.brand.tagline}
          </p>

          <div className="heroActions">
            <a href="#menu">
              View Menu
            </a>

            <a href="#visit">
              Find Us
            </a>
          </div>
        </div>
      </section>

      {/* About */}
      <section
        id="about"
        className={
          media.about
            ? 'section shell aboutSection'
            : 'section shell aboutSection aboutSectionWithoutMedia'
        }
      >
        {media.about && (
          <div className="aboutMedia">
            <Image
              src={mediaSrc(media.about)}
              alt={media.about.alt}
              fill
              sizes="(max-width: 900px) 100vw, 45vw"
              style={{ objectPosition: objectPosition(media.about) }}
            />
          </div>
        )}

        <div className="aboutContent">
          <p className="sectionKicker">
            Who we are
          </p>

          <h2>{content.about.title}</h2>

          <div className="copy">
            {content.about.paragraphs.map(
              (paragraph) => (
                <p key={paragraph}>
                  {paragraph}
                </p>
              )
            )}

            <div className="featureGrid">
              {content.about.features.map(
                (feature) => (
                  <article
                    className="featureCard"
                    key={feature.title}
                  >
                    <span className="featureIcon">
                      {feature.icon}
                    </span>

                    <h3>{feature.title}</h3>

                    <p>{feature.text}</p>
                  </article>
                )
              )}
            </div>
          </div>
        </div>
      </section>

      {/* Menu */}
      <section id="menu" className="section">
        <div className="shell">
          <div className="sectionHeading">
            <p className="sectionKicker">
              Good things to order
            </p>

            <h2>The Menu</h2>

            <p>{content.menuNote}</p>
          </div>

          <div className="menuGrid">
            {menu.categories.map(
              (category) => (
                <article
                  key={category.id}
                  className="menuCategory"
                >
                  <h3>{category.name}</h3>

                  <div>
                    {category.items.map(
                      (item) => (
                        <div
                          className="menuItem"
                          key={item.id}
                        >
                          <div>
                            <h4>{item.name}</h4>
                            <p>{item.description}</p>
                          </div>

                          <strong>
                            {formatMoney(item.price)}
                          </strong>
                        </div>
                      )
                    )}
                  </div>
                </article>
              )
            )}
          </div>
        </div>
      </section>

      {/* Gallery */}
      {media.gallery.length > 0 && (
        <section
          id="gallery"
          className="section gallerySection"
        >
          <div className="shell">
            <div className="sectionHeading">
              <p className="sectionKicker">
                A peek inside
              </p>

              <h2>Gallery</h2>
            </div>

            <Gallery assets={media.gallery} />
          </div>
        </section>
      )}

{/* Reviews */}
{reviewData.reviews.length > 0 && (
  <section
    id="reviews"
    className="section reviewsSection"
  >
    <div className="shell">
      <div className="sectionHeading">
        <p className="sectionKicker">
          Kind words
        </p>

        <h2>What People Say</h2>
      </div>

      <div className="reviewsGrid">
        {reviewData.reviews.map(
          (review) => (
            <article
              className="reviewCard"
              key={review.id}
            >
              <div
                className="reviewStars"
                aria-label={
                  `${review.rating} out of 5 stars`
                }
              >
                <span aria-hidden="true">
                  {'★'.repeat(review.rating)}
                  {'☆'.repeat(
                    5 - review.rating
                  )}
                </span>
              </div>

              <blockquote>
                “{review.body}”
              </blockquote>

              <p className="reviewAuthor">
                — {review.authorName}
              </p>
            </article>
          )
        )}
      </div>
    </div>
  </section>
)}

      {/* Visit */}
      <section
        id="visit"
        className="section shell visit"
      >
        <div>
          <p className="sectionKicker">
            Come say hi
          </p>

          <h2>Visit Us</h2>

          {contact.mapEmbedUrl && (
            <iframe
              className="mapFrame"
              src={contact.mapEmbedUrl}
              loading="lazy"
              title={`${content.brand.name} location`}
            />
          )}
        </div>

        <div className="visitDetails">
          <h3>Address</h3>
          <p>{contact.address}</p>

          <h3>Opening Hours</h3>

          <div className="hoursList">
            {contact.hours.map((hour) => (
              <div
                className="hoursRow"
                key={hour.day}
              >
                <span>{hour.day}</span>
                <span>{hour.time}</span>
              </div>
            ))}
          </div>

          <h3>Contact</h3>

          <p>
            <a
              href={`tel:${contact.phone.replace(
                /[^\d+]/g,
                ''
              )}`}
            >
              {contact.phone}
            </a>

            <br />

            <a href={`mailto:${contact.email}`}>
              {contact.email}
            </a>
          </p>

          <div className="socialLinks">
            {contact.socialLinks.map(
              (link) => (
                <a
                  key={link.platform}
                  href={link.url}
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  {link.platform}
                </a>
              )
            )}
          </div>

          {whatsAppUrl && (
            <a
              className="whatsappLink"
              href={whatsAppUrl}
              target="_blank"
              rel="noopener noreferrer"
            >
              Order on WhatsApp
            </a>
          )}
        </div>
      </section>

      {/* Footer */}
      <footer>
        <div className="shell">
          © {new Date().getFullYear()}{' '}
          {content.brand.name}
        </div>
      </footer>
    </main>
  );
}